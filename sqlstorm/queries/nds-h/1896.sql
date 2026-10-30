WITH CTE_OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_count,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CTE_PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CTE_SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    o.o_orderkey,
    o.total_revenue,
    p.available_quantity,
    s.total_balance,
    CASE 
        WHEN o.order_rank = 1 THEN 'Highest Revenue'
        ELSE 'Regular Order'
    END AS order_type
FROM 
    CTE_OrderSummary o
LEFT JOIN 
    CTE_PartSupplier p ON o.o_orderkey = p.ps_partkey
FULL OUTER JOIN 
    CTE_SupplierDetails s ON p.ps_partkey = s.s_suppkey
WHERE 
    o.o_orderdate >= '1996-01-01' 
    AND (s.total_balance IS NOT NULL OR p.available_quantity > 0)
ORDER BY 
    o.total_revenue DESC, s.total_balance DESC;