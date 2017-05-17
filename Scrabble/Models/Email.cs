using System;
using System.Collections.Generic;

namespace Scrabble.Models
{
    public partial class Email
    {
        public int Id { get; set; }
        public int MemberId { get; set; }
        public string Address { get; set; }

        public virtual Member Member { get; set; }
    }
}
