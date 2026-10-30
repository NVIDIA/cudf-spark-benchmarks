WITH regional_supplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS adjusted_acctbal
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        r.r_name, s.s_suppkey, s.s_name, s.s_acctbal
),
order_details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_receiptdate) AS last_receipt_date,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
qualified_orders AS (
    SELECT 
        od.o_orderkey,
        od.total_revenue,
        od.first_ship_date,
        od.last_receipt_date,
        od.avg_quantity,
        od.distinct_suppliers,
        ROW_NUMBER() OVER (PARTITION BY od.first_ship_date ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        order_details od
    WHERE 
        od.total_revenue >= (
            SELECT AVG(total_revenue) FROM order_details
        )
),
final_report AS (
    SELECT 
        rs.region_name,
        rs.s_name,
        q.total_revenue,
        q.first_ship_date,
        q.last_receipt_date,
        q.avg_quantity,
        q.distinct_suppliers,
        CASE 
            WHEN q.first_ship_date IS NULL THEN 'No Ship Date'
            WHEN q.first_ship_date > cast('1998-10-01' as date) THEN 'Future Ship'
            ELSE 'Valid Ship'
        END AS ship_status
    FROM 
        regional_supplier rs
    JOIN 
        qualified_orders q ON rs.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey IN (
                SELECT l.l_partkey 
                FROM lineitem l 
                WHERE l.l_orderkey IN (
                    SELECT o.o_orderkey 
                    FROM orders o 
                    WHERE o.o_orderstatus = 'O'
                )
            ) 
            LIMIT 1
        )
)
SELECT 
    fr.region_name,
    fr.s_name,
    fr.total_revenue,
    fr.first_ship_date,
    fr.last_receipt_date,
    fr.avg_quantity,
    fr.distinct_suppliers,
    fr.ship_status
FROM 
    final_report fr
WHERE 
    fr.total_revenue IS NOT NULL 
    AND fr.avg_quantity > (SELECT AVG(avg_quantity) FROM qualified_orders)
ORDER BY 
    fr.region_name, fr.total_revenue DESC;