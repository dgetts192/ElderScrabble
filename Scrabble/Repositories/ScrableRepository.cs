using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Scrabble.Models;
using Microsoft.EntityFrameworkCore;

namespace Scrabble.Repositories
{
    public class ScrableRepository : IScrabbleRepository
    {
        private readonly ScrabbleContext context;

        public ScrableRepository(ScrabbleContext context)
        {
            this.context = context;
        }

        public async Task<List<LeaderboardItem>> GetLeaderboard()
        {
            var leaderboard = new List<LeaderboardItem>();
            var conn = context.Database.GetDbConnection();

            try
            {
                await conn.OpenAsync();
                using (var command = conn.CreateCommand())
                {
                    var query = "EXEC [dbo].[Leaderboard_Select]";
                    command.CommandText = query;
                    var reader = await command.ExecuteReaderAsync();

                    if (reader.HasRows)
                    {
                        while (await reader.ReadAsync())
                        {
                            var row = new LeaderboardItem
                            {
                                PlayerId = reader.GetInt32(0),
                                PlayerName = reader.GetString(1),
                                AverageScore = reader.GetInt32(2)
                            };

                            leaderboard.Add(row);
                        }
                    }

                    reader.Dispose();
                }
            }
            finally
            {
                conn.Close();
            }

            return leaderboard;
        }

        public async Task<MemberProfile> GetMemberProfile(int id)
        {
            var memberProfile = new MemberProfile();
            var conn = context.Database.GetDbConnection();

            try
            {
                await conn.OpenAsync();
                using (var command = conn.CreateCommand())
                {
                    var query = $"EXEC [dbo].[Member_Select] @id={id}";
                    command.CommandText = query;
                    var reader = await command.ExecuteReaderAsync();

                    if (reader.HasRows)
                    {
                        while (await reader.ReadAsync())
                        {
                            memberProfile.PlayerId = reader.GetInt32(0);
                            memberProfile.PlayerName = reader.GetString(1);
                            memberProfile.DateOfBirth = DateTime.Parse(reader.GetString(2));
                            memberProfile.TelephoneNumber = reader.GetString(3);
                            memberProfile.EmailAddress = reader.GetString(4);
                            memberProfile.WinCount = reader.GetInt32(5);
                            memberProfile.LossCount = reader.GetInt32(6);
                            memberProfile.AverageScore = reader.GetInt32(7);
                            memberProfile.HighestScore = reader.GetInt32(8);
                            memberProfile.HighestDatePlayed = reader.GetDateTime(9);
                            memberProfile.HighestOpponentId = reader.GetInt32(10);
                            memberProfile.HighestOpponentName = reader.GetString(11);
                            memberProfile.HighestLocation = reader.GetString(12);
                            memberProfile.HighestLongitude = reader.GetDecimal(13);
                            memberProfile.HighestLatitude = reader.GetDecimal(14);
                        }
                    }

                    reader.Dispose();
                }
            }
            finally
            {
                conn.Close();
            }

            return memberProfile;
        }
    }
}
