import React from 'react';
import { Plus, Trash2, GripVertical } from 'lucide-react';
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd';
import type { PipelineStage } from '../../types/database';

interface PipelineStagesProps {
  stages: PipelineStage[];
  onStageAdd: (name: string) => Promise<void>;
  onStageDelete: (id: string) => Promise<void>;
  onStagesReorder: (result: any) => Promise<void>;
  saving: boolean;
}

export default function PipelineStages({ 
  stages, 
  onStageAdd, 
  onStageDelete, 
  onStagesReorder,
  saving 
}: PipelineStagesProps) {
  const [newStageName, setNewStageName] = React.useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStageName.trim()) return;
    await onStageAdd(newStageName);
    setNewStageName('');
  };

  return (
    <div className="shadow sm:rounded-md sm:overflow-hidden">
      <div className="bg-white py-6 px-4 space-y-6 sm:p-6">
        <div>
          <h3 className="text-lg leading-6 font-medium text-gray-900">Pipeline Stages</h3>
          <p className="mt-1 text-sm text-gray-500">
            Customize your hiring pipeline stages
          </p>
        </div>

        <div className="space-y-4">
          <DragDropContext onDragEnd={onStagesReorder}>
            <Droppable droppableId="stages">
              {(provided) => (
                <div
                  {...provided.droppableProps}
                  ref={provided.innerRef}
                  className="space-y-2"
                >
                  {stages.map((stage, index) => (
                    <Draggable
                      key={stage.id}
                      draggableId={stage.id}
                      index={index}
                    >
                      {(provided) => (
                        <div
                          ref={provided.innerRef}
                          {...provided.draggableProps}
                          className="flex items-center space-x-3"
                        >
                          <div
                            {...provided.dragHandleProps}
                            className="cursor-move"
                          >
                            <GripVertical className="h-5 w-5 text-gray-400" />
                          </div>
                          <div className="flex-1 flex items-center justify-between bg-gray-50 rounded-md p-3">
                            <span className="text-sm font-medium text-gray-900">
                              {stage.name}
                            </span>
                            <button
                              type="button"
                              onClick={() => onStageDelete(stage.id)}
                              className="text-red-600 hover:text-red-900"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        </div>
                      )}
                    </Draggable>
                  ))}
                  {provided.placeholder}
                </div>
              )}
            </Droppable>
          </DragDropContext>

          <form onSubmit={handleSubmit} className="mt-4">
            <div className="flex space-x-3">
              <input
                type="text"
                value={newStageName}
                onChange={(e) => setNewStageName(e.target.value)}
                placeholder="New stage name"
                className="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
              />
              <button
                type="submit"
                disabled={!newStageName.trim() || saving}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Stage
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}