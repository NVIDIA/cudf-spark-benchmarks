WITH CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS RankByBalance
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        COUNT(ps.ps_suppkey) > 5
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_discount) < 0.1
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    cd.c_name,
    cd.c_acctbal,
    hvp.p_name,
    ro.total_amount,
    ss.total_supply_cost, 
    CASE 
        WHEN ro.line_count IS NULL THEN 'No Lines'
        ELSE 'Lines Present'
    END AS Order_Line_Status
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    CustomerDetails cd ON c.c_custkey = cd.c_custkey
LEFT JOIN 
    HighValueParts hvp ON cd.c_custkey % 10 = hvp.p_partkey % 10
LEFT JOIN 
    RecentOrders ro ON cd.c_custkey = ro.o_orderkey
LEFT JOIN 
    SupplierStats ss ON hvp.p_partkey = ss.s_suppkey
WHERE 
    (cd.RankByBalance <= 5 OR cd.c_acctbal > 1000)
    AND (ss.total_supply_cost IS NOT NULL OR ss.total_supply_cost IS NULL)
ORDER BY 
    r.r_name, cd.c_acctbal DESC, hvp.p_name;