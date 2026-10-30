WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_sold DESC
    LIMIT 10
)
SELECT 
    rc.c_name,
    rc.total_spent,
    ts.s_name,
    ts.total_supply_cost,
    pp.p_name,
    pp.total_sold
FROM 
    RankedCustomers rc
JOIN 
    TopSuppliers ts ON rc.c_nationkey = ts.s_suppkey
JOIN 
    PopularParts pp ON pp.total_sold > 100
WHERE 
    rc.rank <= 5
ORDER BY 
    rc.total_spent DESC, ts.total_supply_cost DESC;