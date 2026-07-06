using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeterinerAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddReminderSentFlags : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "reminder_sent",
                table: "vaccines",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "reminder_sent",
                table: "appointments",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "reminder_sent",
                table: "vaccines");

            migrationBuilder.DropColumn(
                name: "reminder_sent",
                table: "appointments");
        }
    }
}
