WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS customer_nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.customer_nation
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        p.p_name,
        s.s_name AS supplier_name
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.c_name AS customer_name,
    h.customer_nation,
    COUNT(sd.ps_partkey) AS total_parts_supplied,
    SUM(sd.ps_supplycost) AS total_supply_cost,
    AVG(sd.ps_supplycost) AS avg_supply_cost
FROM 
    HighValueOrders h
LEFT JOIN 
    SupplierDetails sd ON h.o_orderkey = sd.ps_partkey
GROUP BY 
    h.o_orderkey, h.o_orderdate, h.o_totalprice, h.c_name, h.customer_nation
ORDER BY 
    h.o_totalprice DESC;
