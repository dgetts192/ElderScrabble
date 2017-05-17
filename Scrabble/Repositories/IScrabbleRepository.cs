using Scrabble.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Scrabble.Repositories
{
    public interface IScrabbleRepository
    {
        Task<MemberProfile> GetMemberProfile(int id);
        Task<List<LeaderboardItem>> GetLeaderboard();
    }
}
