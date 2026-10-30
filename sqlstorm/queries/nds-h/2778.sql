
WITH SupplierOrderStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns
    FROM
        supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        l.l_shipdate >= '1996-01-01'
    GROUP BY
        s.s_suppkey, s.s_name
), RegionStats AS (
    SELECT
        n.n_nationkey,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey, r.r_name
), RankedSuppliers AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.total_orders ORDER BY s.avg_order_value DESC) AS supplier_rank
    FROM
        SupplierOrderStats s
), FinalReport AS (
    SELECT
        r.region_name,
        rs.s_name,
        rs.total_orders,
        rs.avg_order_value,
        rs.total_returns,
        COALESCE(NULLIF(rs.total_returns, 0), NULL) AS normalized_return_rate
    FROM
        RegionStats r
    JOIN RankedSuppliers rs ON r.supplier_count = rs.total_orders
    WHERE
        rs.supplier_rank <= 5
)
SELECT
    *
FROM
    FinalReport
ORDER BY
    region_name, avg_order_value DESC;
