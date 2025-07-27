#include "raylib.h"

#define RAYLIB_NUKLEAR_IMPLEMENTATION
#include "../external/raylib-nuklear/raylib-nuklear.h"

#define TEXT_BUFFER_SIZE (1024 * 16)

int main(void)
{
    const int screenWidth = 1280;
    const int screenHeight = 720;

    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(screenWidth, screenHeight, "Pogberry Editor");

    SetTargetFPS(60);              

    struct nk_context *ctx = InitNuklear(10); // 10 pt font

    // all the code in one string mayhaps
    static char textBuffer[TEXT_BUFFER_SIZE] = "hi";

    while (!WindowShouldClose())
    {
        UpdateNuklear(ctx);

        if (nk_begin(ctx, "EditorWindow", nk_rect(0, 0, GetScreenWidth(), GetScreenHeight()), NK_WINDOW_NO_SCROLLBAR))
        {
            // push a new style, create the widget then pop the style to avoid affecting other widgets
            nk_style_push_color(ctx, &ctx->style.edit.normal.data.color, nk_rgb(40, 40, 40));
            nk_style_push_color(ctx, &ctx->style.edit.active.data.color, nk_rgb(40, 40, 40));
        
            nk_layout_row_dynamic(ctx, GetScreenHeight() - 10, 1);

            nk_edit_string_zero_terminated(ctx, NK_EDIT_BOX | NK_EDIT_MULTILINE, textBuffer, TEXT_BUFFER_SIZE, nk_filter_default);

            nk_style_pop_color(ctx);
            nk_style_pop_color(ctx);
        }
        nk_end(ctx);

        BeginDrawing();
            ClearBackground(RAYWHITE);
            DrawNuklear(ctx);
        EndDrawing();
    }

    UnloadNuklear(ctx);
    CloseWindow();

    return 0;
}