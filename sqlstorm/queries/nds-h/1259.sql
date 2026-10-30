
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderQuantities AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, r.r_regionkey, r.r_name
),
RankedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_value,
        ss.avg_acctbal,
        RANK() OVER (ORDER BY ss.total_supply_value DESC) AS rank
    FROM SupplierStats ss
    WHERE ss.total_supply_value > 10000
)

SELECT 
    nr.r_name,
    nr.n_nationkey,
    nr.supplier_count,
    rs.s_name,
    rs.total_supply_value,
    rs.avg_acctbal,
    oq.total_quantity,
    CASE 
        WHEN oq.total_quantity IS NULL THEN 'No Orders'
        WHEN oq.total_quantity < 50 THEN 'Low Order Quantity'
        ELSE 'Sufficient Order Quantity' 
    END AS order_quantity_status
FROM NationRegion nr
LEFT JOIN RankedSuppliers rs ON nr.supplier_count > 0
LEFT JOIN OrderQuantities oq ON rs.s_suppkey = oq.o_orderkey
WHERE (rs.avg_acctbal IS NOT NULL OR nr.supplier_count > 5)
ORDER BY nr.r_name, rs.total_supply_value DESC, oq.total_quantity DESC;
