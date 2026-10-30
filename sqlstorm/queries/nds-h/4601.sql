WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
PartSupply AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    si.s_name AS supplier_name,
    si.nation_name,
    ro.o_orderkey,
    ro.o_totalprice
FROM 
    part p
LEFT JOIN 
    PartSupply ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN 
    SupplierInfo si ON l.l_suppkey = si.s_suppkey
WHERE 
    ps.total_available IS NOT NULL
    AND ro.status_rank <= 10
ORDER BY 
    p.p_retailprice DESC, 
    si.s_name ASC;