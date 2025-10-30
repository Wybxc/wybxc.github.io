import { createRoot } from "react-dom/client";
import { useLayoutEffect, useRef, useState } from "react";
import { pdfjs, Document, Page } from 'react-pdf';
import 'react-pdf/dist/Page/AnnotationLayer.css';
import 'react-pdf/dist/Page/TextLayer.css';

pdfjs.GlobalWorkerOptions.workerSrc = new URL(
    'npm:pdfjs-dist/build/pdf.worker.min.mjs',
    import.meta.url,
).toString();

const pdfWide = new URL('./wide.pdf', import.meta.url).toString();
const pdfThin = new URL('./thin.pdf', import.meta.url).toString();

const App = () => {
    const ref = useRef<HTMLDivElement>(null);
    const [width, setWidth] = useState(0);
    const [isWide, setIsWide] = useState(true);

    useLayoutEffect(() => {
        const handleResize = () => {
            setIsWide(window.innerWidth >= 768);
            if (ref.current) {
                setWidth(ref.current.clientWidth);
            }
        };
        handleResize();
        window.addEventListener('resize', handleResize);
        return () => {
            window.removeEventListener('resize', handleResize);
        };
    }, []);

    return <>
        <div ref={ref} style={{ width: "100%", height: "0" }}></div>
        <Document file={isWide ? pdfWide : pdfThin}>
            <Page pageNumber={1} width={width} />
        </Document>
    </>;
};

const container = document.getElementById("content")!;
createRoot(container).render(<App />);