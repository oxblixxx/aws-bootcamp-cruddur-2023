import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { WebTracerProvider, BatchSpanProcessor } from '@opentelemetry/sdk-trace-web';
import { ZoneContextManager } from '@opentelemetry/context-zone';
import { Resource }  from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

// for http request
// import { XMLHttpRequestInstrumentation } from '@opentelemetry/instrumentation-xml-http-request';
// import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';
// import { registerInstrumentations } from '@opentelemetry/instrumentation';


const exporter = new OTLPTraceExporter({
  url: 'https://<your collector endpoint>:443/v1/traces'
});
const provider = new WebTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'browser',
  }),
});
provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register({
  contextManager: new ZoneContextManager()
});


// registerInstrumentations({
//   instrumentations: [
//     new XMLHttpRequestInstrumentation({
//       propagateTraceHeaderCorsUrls: [
//          new RegExp(`${process.env.REACT_APP_BACKEND_URL}`, 'g')
//       ]
//     }),
//     new FetchInstrumentation({
//       propagateTraceHeaderCorsUrls: [
//         new RegExp(`${process.env.REACT_APP_BACKEND_URL}`, 'g') 
//       ]
//     }),
//     new UserInteractionInstrumentation(),
//   ],
// });
