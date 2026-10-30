
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerSegment AS (
    SELECT 
        c.c_nationkey,
        c.c_mktsegment,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey, c.c_mktsegment
),
BizarreJoin AS (
    SELECT 
        r.r_name,
        n.n_name,
        COALESCE(cs.total_spent, 0) AS total_revenue,
        CASE 
            WHEN cs.customer_count IS NULL THEN 'No Customers'
            ELSE CONCAT('Count: ', cs.customer_count)
        END AS customer_info
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        CustomerSegment cs ON n.n_nationkey = cs.c_nationkey
)
SELECT 
    bo.r_name,
    SUM(ss.total_available) AS total_supplies,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    MAX(o.o_totalprice) AS highest_order_price,
    MAX(CASE 
        WHEN bo.total_revenue > 10000 THEN bo.customer_info 
        ELSE 'Below Threshold'
    END) AS customer_status
FROM 
    BizarreJoin bo
LEFT JOIN 
    SupplierStats ss ON bo.n_name LIKE '%' || ss.s_suppkey || '%'
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = (
        SELECT o2.o_orderkey 
        FROM RankedOrders o2 
        WHERE o2.o_orderstatus = 'F'
        AND o2.rnk = 1
    )
GROUP BY 
    bo.r_name
HAVING 
    SUM(ss.total_available) IS DISTINCT FROM AVG(ss.avg_acct_balance) 
    AND COUNT(DISTINCT ss.s_suppkey) > 0
ORDER BY 
    total_supplies DESC, bo.r_name;
