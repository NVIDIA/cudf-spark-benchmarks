
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    ns.n_name AS nation_name, 
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    COALESCE(SUM(rs.total_supplycost), 0) AS total_supplycost,
    AVG(co.total_orders) AS avg_order_value
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank <= 5
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
LEFT JOIN 
    customer cs ON cs.c_nationkey = ns.n_nationkey
GROUP BY 
    ns.n_name
ORDER BY 
    total_supplycost DESC, total_customers DESC;
