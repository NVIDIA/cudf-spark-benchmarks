WITH DetailedInfo AS (
    SELECT 
        p.p_name, 
        s.s_name AS supplier_name, 
        c.c_name AS customer_name, 
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_extended_price,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        s.s_comment AS supplier_comment,
        c.c_comment AS customer_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_retailprice > 10.00 
        AND c.c_acctbal < 500.00 
        AND (s.s_comment LIKE '%high priority%' OR c.c_comment LIKE '%urgent%')
    GROUP BY 
        p.p_name, s.s_name, c.c_name, s.s_comment, c.c_comment
)
SELECT 
    d.p_name, 
    d.supplier_name, 
    d.customer_name,
    d.total_quantity,
    d.avg_extended_price,
    d.order_count,
    CONCAT('Supplier Comm: ', d.supplier_comment, ' | Customer Comm: ', d.customer_comment) AS comments_summary
FROM 
    DetailedInfo d
ORDER BY 
    d.total_quantity DESC, d.avg_extended_price ASC;
