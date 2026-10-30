
WITH  RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
SupplierDetails AS (
    SELECT
        r.r_regionkey,
        n.n_nationkey,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND
        n.n_name NOT LIKE '%land%'
    GROUP BY r.r_regionkey, n.n_nationkey, n.n_name
),
CustomerAnalysis AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal >= 500 OR c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returns_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    rs.s_name,
    sd.nation_name,
    sd.total_cost,
    ca.total_spent,
    li.net_revenue,
    CASE 
        WHEN ca.total_spent IS NULL THEN 'NO ORDERS'
        WHEN li.returns_count = 0 THEN 'NO RETURNS'
        ELSE 'RETURN EXISTS'
    END AS return_status,
    CASE 
        WHEN sd.total_cost IS NULL THEN 'UNKNOWN'
        ELSE 'COST QUOTED'
    END AS cost_status
FROM RankedSuppliers rs
JOIN SupplierDetails sd ON rs.s_suppkey = sd.supplier_count
FULL OUTER JOIN CustomerAnalysis ca ON ca.total_spent IS NOT NULL
LEFT JOIN LineItemStats li ON li.l_orderkey = ca.order_count
WHERE 
    (ca.order_count > 2 AND sd.total_cost > 1000) OR 
    (li.net_revenue IS NOT NULL AND li.net_revenue > 500)
ORDER BY sd.total_cost DESC, ca.order_count ASC;
