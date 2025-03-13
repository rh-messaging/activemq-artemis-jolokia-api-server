import { Headers } from 'node-fetch';
import http from 'http';

export const GetSecretToken = (): string => {
  return process.env.SECRET_ACCESS_TOKEN as string;
};

export interface AuthOptions {
  agent?: http.Agent;
  headers: Headers;
}
