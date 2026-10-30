WITH RankedSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),

TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COALESCE(r.r_name, 'Unknown Region') AS supplier_region,
        s.s_acctbal,
        s.s_comment,
        CASE 
            WHEN s.s_acctbal < 0 THEN 'Negative Balance' 
            ELSE 'Positive Balance' 
        END AS balance_status
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_comment NOT LIKE '%test%' AND
        s.s_acctbal IS NOT NULL
),

QualifiedOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),

FinalReport AS (
    SELECT 
        ts.s_name,
        ts.supplier_region,
        ts.balance_status,
        coalesce(qo.num_orders, 0) AS num_orders,
        coalesce(qo.total_spent, 0) AS total_spent,
        rs.total_revenue
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        QualifiedOrders qo ON ts.s_suppkey = qo.c_custkey
    LEFT JOIN 
        RankedSales rs ON ts.s_suppkey = rs.s_suppkey
)

SELECT 
    fr.s_name,
    fr.supplier_region,
    fr.balance_status,
    fr.num_orders,
    fr.total_spent,
    fr.total_revenue,
    CASE 
        WHEN fr.total_spent > 10000 THEN 'High Value Customer' 
        ELSE 'Standard Customer' 
    END AS customer_category
FROM 
    FinalReport fr
WHERE 
    fr.total_revenue IS NOT NULL
ORDER BY 
    fr.total_revenue DESC, 
    fr.s_name ASC
LIMIT 100;