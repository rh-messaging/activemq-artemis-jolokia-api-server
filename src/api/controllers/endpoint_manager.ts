import { logger } from '../../utils/logger';
import {
  ArtemisJolokia,
  CreateArtemisJolokia,
} from '../apiutil/artemis_jolokia';

export class EndpointManager {
  // endpoint name => endpoint
  endpointsMap: Map<string, ArtemisJolokia>;

  listEndpoints = async (): Promise<ArtemisJolokia[]> => {
    const endpoints = new Map<string, ArtemisJolokia>();
    this.endpointsMap.forEach((value) => {
      if (!endpoints.has(value.name)) {
        endpoints.set(value.name, value);
      }
    });
    return Array.from(endpoints.values());
  };

  getJolokia = (targetEndpoint: string): ArtemisJolokia => {
    if (this.endpointsMap === undefined) {
      this.endpointsMap = new Map<string, ArtemisJolokia>();
    }
    const endpoint = this.endpointsMap.get(targetEndpoint);
    if (endpoint) {
      return endpoint;
    } else {
      logger.debug('creating new Jolokia instance for ', targetEndpoint);
      const jolokia = CreateArtemisJolokia(new URL(targetEndpoint));
      // it supports query on either name or url
      this.endpointsMap.set(targetEndpoint, jolokia);
      this.endpointsMap.set(targetEndpoint, jolokia);
      return jolokia;
    }
  };
}

const endpointManager = new EndpointManager();

export const GetEndpointManager = (): EndpointManager => {
  return endpointManager;
};
