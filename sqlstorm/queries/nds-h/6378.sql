
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        n.n_regionkey,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size IN (5, 10, 15)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    s.s_suppkey,
    s.s_name,
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(s.s_acctbal) AS avg_account_balance
FROM 
    SupplierDetails s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    HighValueOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Europe')
GROUP BY 
    s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
ORDER BY 
    total_quantity DESC, avg_account_balance DESC
LIMIT 100;
