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
  </div>);
}

function App() {
  return (
    <>
      <div className="container">
        {SAMPLES.map((props, i) => <Sample key={i} {...props} />)}
      </div>
    </>
  )
}

export default App
