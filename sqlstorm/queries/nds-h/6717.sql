WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER(PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
), TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        tc.c_name AS top_customer,
        tc.o_totalprice
    FROM 
        RankedOrders tc
    JOIN 
        customer c ON tc.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        tc.rn <= 5
), SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), Summary AS (
    SELECT 
        t.region_name,
        t.nation_name,
        t.top_customer,
        SUM(sd.ps_supplycost * sd.ps_availqty) AS total_supply_cost
    FROM 
        TopCustomers t
    JOIN 
        SupplierDetails sd ON t.top_customer = sd.supplier_name
    GROUP BY 
        t.region_name, t.nation_name, t.top_customer
)
SELECT 
    region_name,
    nation_name,
    top_customer,
    total_supply_cost
FROM 
    Summary
ORDER BY 
    total_supply_cost DESC;