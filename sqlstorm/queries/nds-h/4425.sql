
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate <= DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    od.o_orderkey,
    od.total_line_price,
    CASE 
        WHEN od.total_line_price IS NULL THEN 'No Sales'
        ELSE CONCAT('Total: $', ROUND(od.total_line_price, 2))
    END AS sales_summary
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    OrderDetails od ON r.s_suppkey = od.o_orderkey
WHERE 
    r.supplier_rank = 1 OR od.order_rank = 1
ORDER BY 
    r.s_acctbal DESC, od.o_orderkey ASC;
