WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUBSTRING(s.s_comment, POSITION('|' IN s.s_comment) + 1, 50) AS formatted_comment
    FROM 
        supplier s
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_brand,
        CONCAT(p.p_name, ' ', p.p_brand) AS full_product_name
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
FinalReport AS (
    SELECT 
        si.s_name,
        pi.full_product_name,
        os.o_orderkey,
        os.total_revenue,
        os.o_orderdate,
        os.o_orderstatus,
        CASE 
            WHEN os.total_revenue > 10000 THEN 'High Volume'
            WHEN os.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS revenue_category
    FROM 
        SupplierInfo si
    JOIN 
        partsupp ps ON si.s_suppkey = ps.ps_suppkey
    JOIN 
        PartInfo pi ON ps.ps_partkey = pi.p_partkey
    JOIN 
        OrderSummary os ON pi.p_partkey = os.o_orderkey
)
SELECT 
    revenue_category, 
    COUNT(*) AS order_count, 
    AVG(total_revenue) AS avg_revenue 
FROM 
    FinalReport
GROUP BY 
    revenue_category
ORDER BY 
    revenue_category DESC;
