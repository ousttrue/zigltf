import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { SAMPLES, type SampleType } from './data';
import "./App.css";
const BASE_URL = import.meta.env.BASE_URL;

function Sample(props: SampleType) {
  return (<div className="item">
    <a href={`${BASE_URL}wasm/${props.name}.html`}>
      {props.name}
      <figure>
        <img width={150} height={78} src={`${BASE_URL}wasm/${props.name}.jpg`} />
      </figure>
    </a>

    <ul>
      {props.links.map((link, i) => (
        <li key={i}>
          <a href={link.url}>
            {link.name}
          </a>
        </li>))}
    </ul>
  </div>);
}

function Home() {
  return (<>
    <div className="container">
      {SAMPLES.map((props, i) => <Sample key={i} {...props} />)}
    </div>
  </>);
}

function Page404() {
  return (<>
    <div className="not_found">
      <div>404 not found</div>
    </div>
  </>);
}

function App() {
  return (
    <>
      <BrowserRouter basename={BASE_URL}>
        <Routes>
          <Route index element={<Home />} />
          <Route path="*" element={<Page404 />} />
        </Routes>
      </BrowserRouter>
    </>
  )
}

export default App
