WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.total_order_value) AS total_spent
    FROM 
        customer c
    JOIN 
        OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(os.total_order_value) > 10000
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ts.c_name AS customer_name,
    ts.total_spent AS total_spent,
    ss.s_name AS supplier_name,
    ss.total_parts,
    ss.total_available_qty,
    ss.avg_supply_cost,
    ns.n_name AS nation_name,
    ns.unique_suppliers
FROM 
    TopCustomers ts
JOIN 
    SupplierStats ss ON ts.total_spent > ss.total_available_qty
JOIN 
    supplier s ON ss.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    NationStats ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    ss.avg_supply_cost IS NOT NULL
ORDER BY 
    ts.total_spent DESC, ss.avg_supply_cost ASC
LIMIT 50;