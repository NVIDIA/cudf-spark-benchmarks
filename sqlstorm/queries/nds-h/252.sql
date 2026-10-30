WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1996-01-01' AND 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        tt.total_orders,
        tt.total_revenue,
        tt.avg_quantity
    FROM 
        supplier s
    JOIN (
        SELECT 
            s_suppkey,
            total_orders,
            total_revenue,
            avg_quantity
        FROM 
            SupplierOrderStats
        WHERE 
            rank <= 5
    ) tt ON s.s_suppkey = tt.s_suppkey
)
SELECT 
    ts.s_name,
    ts.total_orders,
    ts.total_revenue,
    ts.avg_quantity,
    CASE 
        WHEN ts.s_acctbal IS NULL THEN 'No Balance'
        WHEN ts.s_acctbal < 1000 THEN 'Low Balance'
        ELSE 'Sufficient Balance'
    END AS balance_status
FROM 
    TopSuppliers ts
ORDER BY 
    ts.total_revenue DESC;