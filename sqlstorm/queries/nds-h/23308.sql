
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months' 
        AND o.o_orderstatus IN ('O', 'F', NULL)
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(s.s_comment, 'No comment') AS supplier_comment,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
), 
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        CASE 
            WHEN SUM(o.o_totalprice) IS NULL THEN 'No Orders' 
            ELSE 'Regular Customer' 
        END AS customer_status
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
), 
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sd.s_name,
    ci.c_name,
    ci.total_spent,
    ROW_NUMBER() OVER (PARTITION BY ro.o_orderstatus ORDER BY ro.o_totalprice DESC) AS order_rank,
    COALESCE(fi.net_sales, 0) AS order_net_sales
FROM 
    RankedOrders ro
LEFT JOIN 
    FilteredLineItems fi ON ro.o_orderkey = fi.l_orderkey
JOIN 
    CustomerInfo ci ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ci.c_custkey)
LEFT JOIN 
    SupplierDetails sd ON sd.part_count > 5 OR sd.part_count IS NULL
WHERE 
    ro.rn <= 10 
    AND ci.total_spent > 1000
ORDER BY 
    ro.o_orderdate ASC, 
    order_rank DESC;
