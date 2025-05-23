import { Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type RagecageData = {
  activeDuel?: RagecageDuel;
  duelTeams: RagecageTeam[];
  trioTeams: RagecageTeam[];
};

type RagecageDuel = {
  firstTeam: RagecageTeam;
  secondTeam: RagecageTeam;
};

type RagecageTeam = {
  members: DuelMember[];
};

type DuelMember = {
  name: string;
  dead: boolean;
  owner: boolean;
};

export function RagecageConsole() {
  const { data, act } = useBackend<RagecageData>();
  const { activeDuel } = data;

  return (
    <Window title="Arena Signup Console" width={600} height={300}>
      <Window.Content>
        {!!activeDuel && (
          <Section title="Active Duel">
            <Stack fill>
              <Stack.Item>
                <DuelTeam team={activeDuel.firstTeam} />
              </Stack.Item>
              <Stack.Item
                style={{ textAlign: 'center', verticalAlign: 'center' }}
              >
                vs
              </Stack.Item>
              <Stack.Item>
                <DuelTeam team={activeDuel.secondTeam} />
              </Stack.Item>
            </Stack>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
}
