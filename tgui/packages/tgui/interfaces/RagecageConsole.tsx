import { Button, Icon, Section, Stack } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type RagecageData = {
  activeDuel?: RagecageDuel;
  duelTeams: RagecageTeam[];
  trioTeams: RagecageTeam[];
  joinRequestCooldown: BooleanLike;
  duelSigned: BooleanLike;
  trioSigned: BooleanLike;
};

type RagecageDuel = {
  firstTeam: RagecageTeam;
  secondTeam: RagecageTeam;
};

type RagecageTeam = {
  members: DuelMember[];
  canJoin: BooleanLike;
  group?: string;
};

type DuelMember = {
  name: string;
  dead: BooleanLike;
  owner: BooleanLike;
};

type DuelTeamProps = {
  team: RagecageTeam;
};

export function DuelTeam(props: DuelTeamProps) {
  const { team } = props;
  const { data, act } = useBackend<RagecageData>();
  return (
    <Section
      buttons={
        !!team.canJoin && (
          <Button
            disabled={data.joinRequestCooldown}
            onClick={() => act('request_join', { ref: team.group })}
          >
            Join Team
          </Button>
        )
      }
    >
      <Stack fill vertical zebra>
        {team.members.map((member) => (
          <Stack.Item key={member.name} textColor={!!member.dead && 'dimgrey'}>
            {member.name}
            {!!member.owner && <Icon name="crown" color="gold" mr={2} />}
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
}

export function RagecageConsole() {
  const { data, act } = useBackend<RagecageData>();
  const { activeDuel, duelTeams, trioTeams, duelSigned, trioSigned } = data;

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
        <Stack fill>
          <Stack.Item>
            <Section
              title="Duel Participants"
              buttons={
                duelSigned ? (
                  <Button color="good" onClick={() => act('duel_signup')}>
                    Sign Up
                  </Button>
                ) : (
                  <Button color="bad" onClick={() => act('duel_drop')}>
                    Leave Queue
                  </Button>
                )
              }
            >
              {duelTeams.map((team, i) => (
                <DuelTeam key={i} team={team} />
              ))}
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section
              title="Trio Participants"
              buttons={
                trioSigned ? (
                  <Button color="good" onClick={() => act('trio_signup')}>
                    Sign Up
                  </Button>
                ) : (
                  <Button color="bad" onClick={() => act('trio_drop')}>
                    Leave Queue
                  </Button>
                )
              }
            >
              {trioTeams.map((team, i) => (
                <DuelTeam key={i} team={team} />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
