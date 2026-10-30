WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(c.c_acctbal) AS total_balance
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
),
JoinedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        cs.total_customers,
        cs.total_balance,
        r.r_name
    FROM 
        part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN CustomerSummary cs ON s.s_nationkey = cs.c_nationkey
    LEFT JOIN region r ON s.s_nationkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, cs.total_customers, cs.total_balance, r.r_name
)
SELECT 
    jd.p_partkey,
    jd.p_name,
    jd.s_name,
    jd.total_sales,
    jd.total_customers,
    jd.total_balance,
    jd.r_name
FROM 
    JoinedData jd
WHERE 
    jd.total_sales > (SELECT AVG(total_sales) FROM JoinedData) 
    AND jd.total_customers IS NOT NULL
ORDER BY 
    jd.total_sales DESC
LIMIT 10;