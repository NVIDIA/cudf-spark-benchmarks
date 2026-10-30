
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank,
        ps.ps_supplycost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000.00
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000.00 AND COUNT(o.o_orderkey) > 10
)
SELECT 
    c.c_name, 
    c.c_acctbal,
    COALESCE(MAX(rs.rank), 0) AS top_supplier_rank,
    ns.n_name AS nation_name,
    CASE 
        WHEN cd.order_count IS NULL THEN 'No orders yet'
        ELSE CONCAT('Spent: $', ROUND(cd.total_spent, 2), ' in ', cd.order_count, ' orders')
    END AS order_summary,
    CASE 
        WHEN COUNT(DISTINCT ps.ps_partkey) = 0 THEN NULL
        ELSE ROUND(AVG(ps.ps_supplycost), 2)
    END AS average_supply_cost
FROM 
    customer c 
LEFT JOIN 
    CustomerOrderDetails cd ON c.c_custkey = cd.c_custkey
LEFT JOIN 
    nation ns ON c.c_nationkey = ns.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (
        SELECT rs2.s_suppkey 
        FROM RankedSuppliers rs2 
        WHERE rs2.rank = 1 AND rs2.s_suppkey IS NOT NULL
        ORDER BY rs2.ps_supplycost DESC
        LIMIT 1
    )
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = rs.s_suppkey
GROUP BY 
    c.c_name, c.c_acctbal, cd.order_count, cd.total_spent, ns.n_name
ORDER BY 
    c.c_acctbal DESC; 
