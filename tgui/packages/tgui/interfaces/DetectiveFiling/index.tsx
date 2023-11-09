/**
 * @file
 * @copyright 2023
 * @author Mylie Daniels (https://github.com/myliedaniels)
 * @license MIT
 */

import { useLocalState } from '../../backend';
import { Stack, Tabs } from '../../components';
import { Window } from '../../layouts';
import { ScansTab } from './ScansTab';
import { DetectiveFilingTabKeys } from './type';

export const DetectiveFiling = (props, context) => {
  const [menu, setMenu] = useLocalState(context, 'menu', DetectiveFilingTabKeys.Scans);

  return (
    <Window title="Case Records" width={600} height={600}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={menu === DetectiveFilingTabKeys.Records}
                onClick={() => setMenu(DetectiveFilingTabKeys.Records)}>
                Records
              </Tabs.Tab>
              <Tabs.Tab
                selected={menu === DetectiveFilingTabKeys.Photos}
                onClick={() => setMenu(DetectiveFilingTabKeys.Photos)}>
                Photos
              </Tabs.Tab>
              <Tabs.Tab
                selected={menu === DetectiveFilingTabKeys.Scans}
                onClick={() => setMenu(DetectiveFilingTabKeys.Scans)}>
                Scans
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item>
            {menu === DetectiveFilingTabKeys.Records && <ScansTab />}
            {menu === DetectiveFilingTabKeys.Photos && <ScansTab />}
            {menu === DetectiveFilingTabKeys.Scans && <ScansTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
