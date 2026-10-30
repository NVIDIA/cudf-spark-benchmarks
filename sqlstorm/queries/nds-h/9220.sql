
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
HighCostSuppliers AS (
    SELECT 
        nation, s_name, total_cost
    FROM 
        RankedSuppliers
    WHERE 
        cost_rank <= 3
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 5
)
SELECT 
    hc.nation AS supplier_nation,
    hc.s_name AS supplier_name,
    tc.c_name AS customer_name,
    tc.total_spent AS customer_spent,
    hc.total_cost AS supplier_total_cost
FROM 
    HighCostSuppliers hc
CROSS JOIN 
    TopCustomers tc
ORDER BY 
    hc.nation, hc.total_cost DESC, tc.total_spent DESC;
