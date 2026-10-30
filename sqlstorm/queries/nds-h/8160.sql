WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(COALESCE(st.total_available_quantity, 0)) AS total_available_quantity
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierStats st ON s.s_suppkey = st.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name AS nation_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    cs.order_count,
    ns.supplier_count,
    ns.total_available_quantity
FROM 
    NationStats ns
JOIN 
    CustomerStats cs ON ns.supplier_count > 0
ORDER BY 
    cs.total_spent DESC,
    ns.total_available_quantity DESC
LIMIT 10;
