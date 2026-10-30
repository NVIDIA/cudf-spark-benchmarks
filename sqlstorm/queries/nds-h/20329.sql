WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
),
CustomerRanking AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    COALESCE(cs.c_custkey, '-1') AS customer_id,
    cs.c_name AS customer_name,
    COALESCE(hv.o_orderkey, '-1') AS high_value_order,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    rs.total_supply_cost,
    hv.total_lineitem_price,
    CASE 
        WHEN cs.customer_rank IS NULL THEN 'Not Ranked' 
        ELSE CAST(cs.customer_rank AS STRING)
    END AS customer_rank
FROM 
    CustomerRanking cs
FULL OUTER JOIN 
    HighValueOrders hv ON cs.c_custkey = hv.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON hv.o_orderkey = rs.s_suppkey
WHERE 
    (rs.total_supply_cost IS NOT NULL OR hv.o_orderkey IS NOT NULL)
    AND (cs.customer_rank IS NOT NULL OR hv.o_totalprice IS NULL)
ORDER BY 
    COALESCE(cs.customer_rank, 999), 
    rs.total_supply_cost DESC, 
    hv.total_lineitem_price DESC;
