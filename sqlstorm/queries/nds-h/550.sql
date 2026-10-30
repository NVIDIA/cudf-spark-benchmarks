
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank_supplier
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    c.c_name AS CustomerName,
    spd.p_name AS ProductName,
    spd.s_name AS SupplierName,
    (CASE 
        WHEN l.l_returnflag = 'Y' THEN 'Returned' 
        ELSE 'Not Returned' 
     END) AS ReturnStatus,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    r.o_orderdate AS OrderDate
FROM 
    lineitem l
JOIN 
    RankedOrders r ON l.l_orderkey = r.o_orderkey
JOIN 
    SupplierPartDetails spd ON l.l_partkey = spd.p_partkey AND spd.rank_supplier = 1
JOIN 
    CustomerDetails c ON c.c_custkey = r.o_orderkey
WHERE 
    l.l_shipdate BETWEEN DATE '1998-10-01' - INTERVAL '3 MONTH' AND DATE '1998-10-01'
GROUP BY 
    c.c_name, spd.p_name, spd.s_name, l.l_returnflag, r.o_orderdate
ORDER BY 
    TotalRevenue DESC, CustomerName;
