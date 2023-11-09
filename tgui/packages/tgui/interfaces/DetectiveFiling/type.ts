/**
 * @file
 * @copyright 2023
 * @author Mylie Daniels (https://github.com/myliedaniels)
 * @license MIT
 */

export interface ScansTabData {
  scans_data: ScanProps[]
}

export interface ScanProps {
  scanned_name: string;
  scan_results: string;
  scan_notes: string;
  scan_index: number;
}

export enum DetectiveFilingTabKeys {
  Records,
  Photos,
  Scans,
}
