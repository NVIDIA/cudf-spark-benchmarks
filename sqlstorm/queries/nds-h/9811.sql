
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    pd.p_name,
    sd.s_name,
    sd.s_acctbal
FROM 
    TopOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    part pd ON l.l_partkey = pd.p_partkey
JOIN 
    SupplierDetails sd ON pd.p_partkey = sd.ps_partkey
ORDER BY 
    o.o_totalprice DESC, 
    o.o_orderdate ASC
LIMIT 10;
