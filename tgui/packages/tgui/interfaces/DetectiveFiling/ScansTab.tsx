/**
 * @file
 * @copyright 2023
 * @author Mylie Daniels (https://github.com/myliedaniels)
 * @license MIT
 */

import { useBackend } from '../../backend';
import { Box, Button, Collapsible, Divider, Section } from '../../components';
import { ScanProps, ScansTabData } from './type';

export const ScansTab = (props, context) => {
  const { data } = useBackend<ScansTabData>(context);

  return (
    <Box>
      {data.scans_data?.map((scan, index) =>
        (<Scan
          key={index}
          {...scan}
        />)
      )}
    </Box>
  );
};

const Scan = (props: ScanProps, context) => {
  const { act } = useBackend(context);
  const {
    scanned_name,
    scan_results,
    scan_notes,
    scan_index,
  } = props;

  return (
    <Box
      my={2}>
      <Collapsible
        title={scanned_name}
        fontSize={1.2}
        bold>
        <Section
          mt={-1.1}>
          <Box>
            {scan_results}
          </Box>
          <Divider />
          <Button.Input
            multiline
            fluid
            maxLength={300}
            tooltip="Click to enter notes"
            color="transparent"
            textColor="#FFFFFF"
            content={scan_notes}
            defaultValue={scan_notes}
            currentValue={scan_notes}
            onCommit={(e, new_content) => act('write_note', {
              note_index: scan_index,
              new_note: new_content,
            })}
          />
        </Section>
      </Collapsible>
    </Box>
  );
};
