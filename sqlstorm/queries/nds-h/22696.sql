WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierStatistics AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS avg_account_balance,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High Value'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        customer c
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    cs.customer_value_segment,
    COUNT(DISTINCT li.l_orderkey) AS total_line_items,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    CASE 
        WHEN COUNT(li.l_orderkey) > 0 THEN 
            SUM(li.l_extendedprice * (1 - li.l_discount)) / COUNT(li.l_orderkey)
        ELSE 
            NULL
    END AS avg_revenue_per_line_item
FROM 
    RankedOrders r
LEFT OUTER JOIN 
    lineitem li ON r.o_orderkey = li.l_orderkey
LEFT OUTER JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
LEFT OUTER JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    CustomerSegment cs ON r.o_orderkey = cs.c_custkey
WHERE 
    r.order_rank <= 5
GROUP BY 
    r.o_orderkey, 
    r.o_orderdate, 
    s.s_name,
    cs.customer_value_segment
HAVING 
    SUM(li.l_discount) < 0.2
ORDER BY 
    total_revenue DESC
LIMIT 100;