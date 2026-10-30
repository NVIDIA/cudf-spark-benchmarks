WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 50000
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
)
SELECT 
    roc.o_orderkey,
    roc.o_orderstatus,
    roc.o_totalprice,
    hvc.c_custkey,
    hvc.c_name,
    spd.s_suppkey,
    spd.s_name,
    spd.p_partkey,
    spd.p_name,
    spd.total_available,
    COUNT(*) OVER() AS total_records
FROM 
    RankedOrders roc
JOIN 
    HighValueCustomers hvc ON roc.o_orderkey = hvc.c_custkey
JOIN 
    SupplierPartDetails spd ON roc.o_orderkey = spd.p_partkey
WHERE 
    roc.order_rank <= 10
ORDER BY 
    roc.o_orderdate DESC, roc.o_totalprice ASC;