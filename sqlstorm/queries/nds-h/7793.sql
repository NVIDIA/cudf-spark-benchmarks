
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        o.o_custkey
    FROM 
        orders o
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_type
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 5000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    ps.ps_supplycost,
    pn.nation,
    COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    PartSupplier ps ON l.l_partkey = ps.ps_partkey
JOIN 
    CustomerNation pn ON r.o_custkey = pn.c_custkey
WHERE 
    r.order_rank <= 10
GROUP BY 
    r.o_orderkey, r.o_orderdate, r.o_totalprice, ps.ps_supplycost, pn.nation
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
