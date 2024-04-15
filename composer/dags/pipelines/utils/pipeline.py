from typing import Iterable

class Step:
    def __init__(self, data: any = None):
        self.data = data
        
    def process(self):
        return self.data
    
class Pipeline:
    def __init__(self, steps: Iterable[Step], initial_data: any = None):
        self.steps = steps
        self.result = initial_data
        
    def run(self):
        result = self.result
        for step in self.steps:
            if not result:
                result = step().process()
            result = step(result).process()
            
        self.result = result
