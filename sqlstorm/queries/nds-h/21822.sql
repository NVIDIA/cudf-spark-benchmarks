
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
),
CustomerSums AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey
    FROM 
        CustomerSums cs
    WHERE 
        cs.total_spent IS NOT NULL AND cs.total_spent > (
            SELECT 
                AVG(cs2.total_spent) 
            FROM 
                CustomerSums cs2
        )
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) >= 3
),
OrderLineStats AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
        COUNT(CASE WHEN li.l_returnflag = 'R' THEN 1 END) AS returns_count
    FROM 
        lineitem li 
    GROUP BY 
        li.l_orderkey
)
SELECT 
    p.p_name,
    p.p_brand,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    MAX(li.l_shipdate) AS last_ship_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(li.l_extendedprice * (1 - li.l_discount)) > 100000 THEN 'High'
        WHEN SUM(li.l_extendedprice * (1 - li.l_discount)) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
WHERE 
    li.l_shipdate <= DATE '1998-10-01' AND li.l_discount < 0.10
GROUP BY 
    p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT p.p_partkey) > 1 
    AND SUM(li.l_extendedprice) IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 100;
