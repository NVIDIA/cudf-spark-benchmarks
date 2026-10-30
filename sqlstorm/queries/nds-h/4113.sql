WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
RankedSuppliers AS (
    SELECT 
        ss.*,
        RANK() OVER (PARTITION BY n.r_regionkey ORDER BY ss.total_supply_cost DESC) AS regional_rank
    FROM SupplierSummary ss
    JOIN NationRegion n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_acctbal >= 1000 LIMIT 1)
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    s.s_name AS supplier_name,
    s.total_parts,
    s.total_supply_cost,
    CASE 
        WHEN s.total_supply_cost < 500 THEN 'Low' 
        WHEN s.total_supply_cost BETWEEN 500 AND 1000 THEN 'Medium' 
        ELSE 'High' 
    END AS cost_category,
    od.total_revenue,
    od.lineitem_count
FROM RankedSuppliers s
LEFT JOIN OrderDetails od ON s.s_suppkey = od.o_orderkey
JOIN NationRegion ns ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c ORDER BY c.c_acctbal DESC LIMIT 1)
JOIN region r ON r.r_regionkey = ns.r_regionkey
WHERE s.regional_rank <= 3
ORDER BY r.r_name, s.total_supply_cost DESC;