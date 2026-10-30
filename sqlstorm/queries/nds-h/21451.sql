WITH  price_calculation AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_orderkey) AS orders_count,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS row_num
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
), region_sum AS (
    SELECT 
        r.r_regionkey,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
), top_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pc.total_price,
        pc.orders_count
    FROM 
        part p
    JOIN 
        price_calculation pc ON p.p_partkey = pc.ps_partkey
    WHERE 
        pc.row_num = 1 AND pc.total_price IS NOT NULL
), customer_avg AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), combined_data AS (
    SELECT 
        tp.p_name,
        tp.total_price,
        tp.orders_count,
        ra.total_acctbal,
        ca.average_order_value
    FROM 
        top_parts tp
    JOIN 
        region_sum ra ON EXISTS (
            SELECT 1 
            FROM supplier s
            WHERE ra.total_acctbal > 0 AND s.s_acctbal < ra.total_acctbal
        )
    LEFT JOIN 
        customer_avg ca ON tp.orders_count > ca.average_order_value
)
SELECT 
    cd.p_name,
    cd.total_price,
    cd.orders_count,
    COALESCE(cd.total_acctbal, 0) AS adjusted_acctbal,
    CASE 
        WHEN cd.orders_count IS NULL THEN 'No Orders'
        WHEN cd.total_price IS NULL THEN 'No Price'
        ELSE 'Data Available'
    END AS status
FROM 
    combined_data cd
WHERE 
    cd.total_price >= (SELECT AVG(total_price) FROM combined_data) 
OR 
    cd.orders_count < 5
ORDER BY 
    cd.total_price DESC, 
    cd.orders_count ASC 
LIMIT 10;
