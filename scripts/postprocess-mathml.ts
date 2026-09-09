import { join } from "node:path";
import { unified } from "npm:unified@11.0.5";
import rehypeParse from "npm:rehype-parse@9.0.1";
import rehypeStringify from "npm:rehype-stringify@10.0.1";
import type { Element, Node, Root } from "npm:@types/hast@3.0.5";

const processor = unified().use(rehypeParse).use(rehypeStringify);

function isElement(node: Node): node is Element {
  return node.type === "element";
}

function propertyString(
  properties: Record<string, unknown>,
  name: string,
): string | undefined {
  const value = properties[name];
  return typeof value === "string" || typeof value === "number"
    ? String(value)
    : undefined;
}

function hasClass(
  properties: Record<string, unknown>,
  className: string,
): boolean {
  const value = properties.className ?? properties.class;
  if (Array.isArray(value)) {
    return value.some((item) => item === className);
  }
  return typeof value === "string" && value.split(/\s+/).includes(className);
}

function styleLength(style: string, name: string): string | undefined {
  const match = style.match(
    new RegExp(`(?:^|;)\\s*${name}\\s*:\\s*([^;]+)`, "i"),
  );
  return match?.[1].trim();
}

function isFixedLength(value: string): boolean {
  return !/(%|calc\(|var\(|min\(|max\(|clamp\()/i.test(value) &&
    !/^(auto|inherit|initial|unset|revert)$/i.test(value);
}

function centeredHdw(
  height: string,
  width: string,
): string | undefined {
  const match = height.match(
    /^([+-]?(?:\d+(?:\.\d*)?|\.\d+))([a-z]+)?$/i,
  );
  if (!match) {
    return undefined;
  }

  const value = Number(match[1]);
  const unit = match[2] ?? "";
  if (!Number.isFinite(value)) {
    return undefined;
  }

  const half = value / 2;
  // MathJax's default CHTML fonts place the mathematical axis at .25em
  // above the baseline.  An em value is required so this offset scales with
  // the surrounding MathJax font size.
  if (unit === "" || unit.toLowerCase() === "em") {
    const axis = 0.25;
    if (half >= axis) {
      const suffix = unit || "em";
      return `${half + axis}${suffix} ${half - axis}${suffix} ${width}`;
    }
  }

  // For other fixed units, the postprocessor cannot know the local em size.
  // Keep the SVG centered around the baseline rather than guessing a scale.
  const halfLength = `${half}${unit}`;
  return `${halfLength} ${halfLength} ${width}`;
}

/** Supply a stable bbox for fixed-size SVG embedded in MathML. */
function addSvgHdw(svg: Element): void {
  const properties = svg.properties as Record<string, unknown>;
  if (properties["data-mjx-hdw"] !== undefined) {
    return;
  }

  const style = propertyString(properties, "style") ?? "";
  const width = styleLength(style, "width") ??
    propertyString(properties, "width");
  const height = styleLength(style, "height") ??
    propertyString(properties, "height");
  if (width && height && isFixedLength(width) && isFixedLength(height)) {
    const hdw = centeredHdw(height, width);
    if (hdw) {
      properties["data-mjx-hdw"] = hdw;
    }
  }
}

function semanticsFor(svg: Element): Element {
  addSvgHdw(svg);
  return {
    type: "element",
    tagName: "semantics",
    properties: {},
    children: [{
      type: "element",
      tagName: "annotation-xml",
      properties: { encoding: "image/svg+xml" },
      children: [svg],
    }],
  };
}

function wrapSvgDescendants(parent: Element): number {
  if (parent.tagName === "semantics" || parent.tagName === "annotation-xml") {
    return 0;
  }

  let wrapped = 0;
  for (const child of parent.children) {
    if (!isElement(child)) {
      continue;
    }
    if (child.tagName === "svg") {
      const index = parent.children.indexOf(child);
      parent.children[index] = semanticsFor(child);
      wrapped += 1;
    } else {
      wrapped += wrapSvgDescendants(child);
    }
  }
  return wrapped;
}

/** Put one presentation semantics node directly under each math. */
function liftMathSemantics(math: Element): number {
  if (
    math.children.some(
      (child) => isElement(child) && child.tagName === "semantics",
    )
  ) {
    return 0;
  }

  const wrapped = wrapSvgDescendants(math);
  if (wrapped === 0) {
    return 0;
  }

  // MathJax requires the first child of a top-level semantics node to be a
  // valid presentation expression. The SVG remains inside its own nested
  // annotation-xml, where MathJax parses it as XML rather than as MathML.
  const presentation: Element = {
    type: "element",
    tagName: "mrow",
    properties: {},
    children: math.children,
  };
  const semantics: Element = {
    type: "element",
    tagName: "semantics",
    properties: {},
    children: [presentation],
  };
  math.children = [semantics];
  return wrapped;
}

function alignMtable(node: Element): number {
  let colCount = 0;
  for (const row of node.children) {
    if (isElement(row) && row.tagName === "mtr") {
      colCount = Math.max(colCount, row.children.length);
    }
  }

  if (colCount <= 1) {
    return 0;
  }

  const properties = node.properties as Record<string, unknown>;
  // Typst's cases environment is left-aligned in every column. Other
  // multi-column tables use the alternating alignment emitted by the layout.
  const alignment = hasClass(properties, "cases") ? "left" : Array.from(
    { length: colCount },
    (_, index) => (index % 2 === 0 ? "right" : "left"),
  ).join(" ");
  if (properties.columnalign === alignment) {
    return 0;
  }

  properties.columnalign = alignment;
  return 1;
}

function transformNode(node: Node): number {
  if (!isElement(node)) {
    return 0;
  }

  let wrapped = 0;
  if (node.tagName === "math") {
    wrapped += liftMathSemantics(node);
  }
  if (node.tagName === "mtable") {
    wrapped += alignMtable(node);
  }
  for (const child of node.children) {
    wrapped += transformNode(child);
  }
  return wrapped;
}

function transform(tree: Root): number {
  return tree.children.reduce(
    (wrapped, child) => wrapped + transformNode(child),
    0,
  );
}

async function htmlFiles(root: string): Promise<string[]> {
  const files: string[] = [];
  for await (const entry of Deno.readDir(root)) {
    const path = join(root, entry.name);
    if (entry.isDirectory) {
      files.push(...(await htmlFiles(path)));
    } else if (entry.isFile && entry.name.endsWith(".html")) {
      files.push(path);
    }
  }
  return files;
}

async function processFile(path: string): Promise<boolean> {
  const source = await Deno.readTextFile(path);
  const tree: Root = processor.parse(source);
  if (transform(tree) === 0) {
    return false;
  }

  await Deno.writeTextFile(path, processor.stringify(tree));
  return true;
}

const [site] = Deno.args;
if (!site) {
  console.error("usage: deno run ... scripts/postprocess-mathml.ts <site>");
  Deno.exit(2);
}

const files = await htmlFiles(site);
let changed = 0;
for (const file of files) {
  if (await processFile(file)) {
    changed += 1;
  }
}
console.log(`mathml-svg-semantics: updated ${changed} HTML file(s)`);
