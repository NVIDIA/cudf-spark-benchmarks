
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_acctbal AS customer_balance,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.customer_name,
        ro.customer_balance
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        s.s_name AS supplier_name
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.customer_name,
    hvo.customer_balance,
    sp.p_name,
    sp.p_brand,
    sp.p_retailprice,
    sp.supplier_name
FROM 
    HighValueOrders hvo
JOIN 
    lineitem li ON hvo.o_orderkey = li.l_orderkey
JOIN 
    SupplierParts sp ON li.l_partkey = sp.ps_partkey
WHERE 
    hvo.o_totalprice > 500
ORDER BY 
    hvo.o_totalprice DESC;
