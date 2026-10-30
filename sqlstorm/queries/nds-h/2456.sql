WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(os.o_totalprice), 0) AS total_order_value,
    COALESCE(AVG(ss.part_count), 0) AS avg_parts_per_supplier,
    CASE 
        WHEN COUNT(DISTINCT os.o_orderkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS supplier_status
FROM 
    nation n
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN 
    OrderStats os ON n.n_nationkey = os.c_nationkey AND os.rnk <= 5
GROUP BY 
    n.n_name
HAVING 
    SUM(ss.total_supply_cost) > 0 OR SUM(os.o_totalprice) > 0
ORDER BY 
    total_supply_cost DESC, total_order_value DESC;
